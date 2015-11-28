/**
 *	The MIT License (MIT)
 *
 *	Copyright (c) 2015 Jens Meder
 *
 *	Permission is hereby granted, free of charge, to any person obtaining a copy of
 *	this software and associated documentation files (the "Software"), to deal in
 *	the Software without restriction, including without limitation the rights to
 *	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 *	the Software, and to permit persons to whom the Software is furnished to do so,
 *	subject to the following conditions:
 *
 *	The above copyright notice and this permission notice shall be included in all
 *	copies or substantial portions of the Software.
 *
 *	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 *	FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 *	COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 *	IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 *	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "JMTaggedPacketProtocol.h"

@implementation JMTaggedPacketProtocol
{
	@private
	
	NSMutableData* _buffer;
}

-(instancetype)init
{
	self = [super init];
	
	if (self)
	{
		_buffer = [NSMutableData data];
	}
	
	return self;
}

-(NSData *)encodePacket:(JMTaggedPacket *)packet
{
	uint32_t packetLength = CFSwapInt32HostToBig((uint32_t)packet.data.length);
	uint16_t tag = CFSwapInt16HostToBig(packet.tag);
	
	NSMutableData* data = [NSMutableData dataWithBytes:&packetLength length:sizeof(uint32_t)];
	[data appendBytes:&tag length:sizeof(tag)];
	[data appendData:packet.data];
	
	return data;
}

-(NSArray<JMTaggedPacket *> *)processData:(NSData *)data
{
	[_buffer appendData:data];
	
	uint32_t length = 0;
	uint16_t tag = 0;
	
	if (_buffer.length < sizeof(length) + sizeof(tag))
	{
		return nil;
	}
	
	[_buffer getBytes:&length length:sizeof(length)];
	[_buffer getBytes:&tag range:NSMakeRange(sizeof(length), sizeof(tag))];
	
	length = CFSwapInt32BigToHost(length);
	tag = CFSwapInt16BigToHost(tag);
	
	NSMutableArray<JMTaggedPacket*>* packets = [NSMutableArray array];
	
	while (sizeof(length) + sizeof(tag) + length <= _buffer.length)
	{
		NSData* packetData = [_buffer subdataWithRange:NSMakeRange(sizeof(length) + sizeof(tag), length)];
		JMTaggedPacket* packet = [[JMTaggedPacket alloc]initWithData:packetData andTag:tag];
		[packets addObject:packet];
		
		[_buffer replaceBytesInRange:NSMakeRange(0, sizeof(length) + sizeof(tag) + length) withBytes:NULL length:0];
		[_buffer getBytes:&length length:sizeof(length)];
		[_buffer getBytes:&tag range:NSMakeRange(sizeof(length), sizeof(tag))];
		
		length = CFSwapInt32BigToHost(length);
		tag = CFSwapInt16BigToHost(tag);
	}
	
	return packets;
}

-(void)reset
{
	_buffer = [NSMutableData data];
}

@end
